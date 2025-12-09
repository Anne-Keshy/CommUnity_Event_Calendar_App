#!/usr/bin/env python3
"""
Example script showing how to switch from xAI (via Openrouter) to other AI providers using litellm.
This addresses the overload error by using alternative providers.
"""

import os
import litellm
from litellm import completion

# Set your API keys as environment variables for security
# For OpenAI: export OPENAI_API_KEY="your-openai-key"
# For Anthropic: export ANTHROPIC_API_KEY="your-anthropic-key"
# For Openrouter (if still needed): export OPENROUTER_API_KEY="your-openrouter-key"

def chat_with_openai(message):
    """
    Example using OpenAI's GPT-3.5-turbo model
    """
    try:
        response = completion(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": message}],
            api_key=os.getenv("OPENAI_API_KEY")
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"OpenAI Error: {e}")
        return None

def chat_with_anthropic(message):
    """
    Example using Anthropic's Claude-3-Haiku model
    """
    try:
        response = completion(
            model="claude-3-haiku-20240307",
            messages=[{"role": "user", "content": message}],
            api_key=os.getenv("ANTHROPIC_API_KEY")
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"Anthropic Error: {e}")
        return None

def chat_with_openrouter_fallback(message):
    """
    Example using Openrouter with a different provider (not xAI)
    """
    try:
        # Use a different model, e.g., Anthropic via Openrouter
        response = completion(
            model="openrouter/anthropic/claude-3-haiku",
            messages=[{"role": "user", "content": message}],
            api_key=os.getenv("OPENROUTER_API_KEY")
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"Openrouter Error: {e}")
        return None

def main():
    """
    Main function demonstrating provider switching
    """
    user_message = "Hello, can you help me with a coding question?"

    print("Testing different AI providers...\n")

    # Try OpenAI first
    print("1. Trying OpenAI:")
    openai_response = chat_with_openai(user_message)
    if openai_response:
        print(f"Response: {openai_response[:100]}...\n")
    else:
        print("Failed\n")

    # Try Anthropic
    print("2. Trying Anthropic:")
    anthropic_response = chat_with_anthropic(user_message)
    if anthropic_response:
        print(f"Response: {anthropic_response[:100]}...\n")
    else:
        print("Failed\n")

    # Try Openrouter with different provider
    print("3. Trying Openrouter (non-xAI provider):")
    openrouter_response = chat_with_openrouter_fallback(user_message)
    if openrouter_response:
        print(f"Response: {openrouter_response[:100]}...\n")
    else:
        print("Failed\n")

if __name__ == "__main__":
    main()
